export interface TaskContext {
  values: Record<string, string | number | boolean>;
}

export interface TaskStep {
  id: string;
  label: string;
  run: (context: TaskContext) => Promise<Partial<TaskContext['values']>>;
}

export interface TaskProgress {
  stepIndex: number;
  total: number;
  step: TaskStep;
}

export interface TaskRun {
  promise: Promise<TaskContext>;
  pause: () => void;
  resume: () => void;
  cancel: () => void;
}

export class TaskCancelledError extends Error {
  constructor() {
    super('Task execution was cancelled.');
    this.name = 'TaskCancelledError';
  }
}

export function runTask(
  steps: TaskStep[],
  initialValues: TaskContext['values'],
  onProgress?: (progress: TaskProgress) => void,
): TaskRun {
  let paused = false;
  let cancelled = false;
  let resumeWaiter: (() => void) | null = null;

  const waitUntilResumed = async (): Promise<void> => {
    if (!paused) return;
    await new Promise<void>((resolve) => {
      resumeWaiter = resolve;
    });
  };

  const promise = (async () => {
    const context: TaskContext = { values: { ...initialValues } };
    for (let index = 0; index < steps.length; index += 1) {
      if (cancelled) throw new TaskCancelledError();
      await waitUntilResumed();
      if (cancelled) throw new TaskCancelledError();
      const step = steps[index];
      onProgress?.({ stepIndex: index, total: steps.length, step });
      const result = await step.run(context);
      const definedValues = Object.entries(result).reduce<Record<string, string | number | boolean>>((values, [key, value]) => {
        if (value !== undefined) values[key] = value;
        return values;
      }, {});
      context.values = { ...context.values, ...definedValues };
    }
    return context;
  })();

  return {
    promise,
    pause: () => {
      paused = true;
    },
    resume: () => {
      paused = false;
      resumeWaiter?.();
      resumeWaiter = null;
    },
    cancel: () => {
      cancelled = true;
      resumeWaiter?.();
      resumeWaiter = null;
    },
  };
}
